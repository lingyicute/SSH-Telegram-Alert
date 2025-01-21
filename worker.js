// Cloudflare Worker configuration
export default {
  async fetch(request, env) {
    // 只接受 POST 请求
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    // 验证 Authorization header
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || authHeader !== `Bearer ${env.AUTH_TOKEN}`) {
      return new Response('Unauthorized', { status: 401 });
    }

    try {
      // 解析请求数据
      const data = await request.json();
      
      // 验证必要字段
      if (!data.text) {
        return new Response('Missing required fields', { status: 400 });
      }

      // 使用环境变量中的chat_ids
      const chatIds = env.CHAT_IDS.split(',').map(id => id.trim());
      
      // 发送到所有配置的chat_id
      const results = await Promise.all(chatIds.map(async (chatId) => {
        // 构建发送到 Telegram 的请求
        const telegramUrl = `https://api.telegram.org/bot${env.BOT_TOKEN}/sendMessage`;
        const telegramResponse = await fetch(telegramUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            chat_id: chatId,
            text: data.text,
            parse_mode: 'markdown',
            disable_web_page_preview: true
          }),
        });

        return await telegramResponse.json();
      }));

      // 检查是否所有消息都发送成功
      const failures = results.filter(result => !result.ok);
      if (failures.length > 0) {
        throw new Error(`Some messages failed to send: ${JSON.stringify(failures)}`);
      }
      
      // 构建成功响应
      const responseData = {
        status: 'success',
        results: results
      };

      const responseHeaders = {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store',
      };
      
      return new Response(JSON.stringify(responseData), {
        status: 200,
        headers: responseHeaders,
      });

    } catch (error) {
      // 构建错误响应
      const errorResponse = {
        status: 'error',
        error: error.message
      };

      const responseHeaders = {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store',
      };

      return new Response(JSON.stringify(errorResponse), {
        status: 500,
        headers: responseHeaders,
      });
    }
  },
} 