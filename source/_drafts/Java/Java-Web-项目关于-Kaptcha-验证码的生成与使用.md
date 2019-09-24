---
title: Java Web 项目关于 Kaptcha 验证码的生成与使用
comments: true
date: 2017-05-18 13:22:56
tags:
- Java
- Captcha
- Spring
---

Web  端中，为了防止恶意的流量攻击或者为了防止自动化提交，都会在页面中引入验证码。
验证码一般是一些加入了干扰线，做了模糊处理的字符图片，可能是中文、字母、数字等。现在一些网站还加入了语音验证或者手机验证。

验证码实现流程如下：
1. Web  请求验证码图片
2. 后台生成随机字符，例如 ABCD，存入 Session 或 Cache
3. 后台将 ABCD 做模糊处理，并以图片形式返回给前端
4. 前端提交表单时，将验证码一并带上
5. 后台将前端提交的验证码与存在 Session 或 Cache  中的验证码比较。如果一致，则成功。

在实践中，可以采用自己绘制验证码图片，原理就是在图片上增加干扰线，干扰点，变形等处理。可以参考这篇博文 [java web项目生成验证码的解决方案](http://blog.csdn.net/chenghui0317/article/details/12526439)。


![](http://nutslog.qiniudn.com/17-5-18/91270701-file_1495074709422_c1ef.jpg "Kaptcha 实现效果")

# 引入 Kaptcha 库
以下为 Maven  代码
```xml
<!-- Kaptcha验证码框架 -->
<dependency>
    <groupId>com.github.axet</groupId>
    <artifactId>kaptcha</artifactId>
    <version>0.0.9</version>
</dependency>
```

或者去 Google Code 下载，地址为 https://code.google.com/archive/p/kaptcha/

# Kaptcha 使用
Kapthca  使用可以有以下两种方法，一种是直接请求图片，验证码写在 Session  中；另一种是作为 WebService ，由前端主动请求。

## 通过 img 标签请求
通过 img  标签，直接获取验证码图片，这个场景适合 JSP  工程这种前后端不完全分离的，或者仅使用未禁止 Session  和 Cookie  的浏览器时。

### 后台 web.xml 配置
在根目录下增加 servlet  和 servlet-mapping
```XML
<!-- 登陆验证码 Kaptcha -->
<servlet>
    <servlet-name>Kaptcha</servlet-name>
    <servlet-class>com.google.code.kaptcha.servlet.KaptchaServlet</servlet-class>
    <!-- 验证码各项配置 -->
    <init-param>
        <param-name>kaptcha.border</param-name>
        <param-value>no</param-value>
    </init-param>
    <init-param>
        <param-name>kaptcha.textproducer.font.color</param-name>
        <param-value>red</param-value>
    </init-param>
    <init-param>
        <param-name>kaptcha.textproducer.char.space</param-name>
        <param-value>3</param-value>
    </init-param>
</servlet>
<servlet-mapping>
    <servlet-name>Kaptcha</servlet-name>
    <!-- img src 指定格式 -->
    <url-pattern>/kaptcha.jpg</url-pattern>
</servlet-mapping>
```

### 前端 img 请求
只需要一行代码即可。
> 注意，**此处 kaptcha.jpg 要与 web.xml 中 servlet-mapping 中指定的名字一致。**

`<img src="http://localhost:7010/kaptcha.jpg"/>`

### 后台验证
**Kaptcha  默认会将生成的验证码写入 Session ，因此这需要前端浏览器允许记录 Cookies **，否则可能出现 SessionId  不一致使得验证码无法正确校验。在将 Html5  嵌入 iOS App  时，由于内嵌浏览器对 Cookie  做了严格的限制，使得无法正确校验，才转向了第二种方法。
因为验证码被记录在 Session  中，因此 Web  端从 Session  中取出即可，至于如何获得 Session ，视不同项目而定。一般 JSP  项目用这种方法，其校验方法如下：：

```jsp
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head>
        <%@ page language="java" contentType="text/html; charset=UTF-8" %>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Kaptcha Example</title>
    </head>
    <body>
        Enter in the <a href="http://code.google.com/p/kaptcha/">Kaptcha</a> to see if it matches what is stored in the session attributes.
        <table>
            <tr>
                <td><img src="kaptcha.jpg"></td>
                <td valign="top">
                    <form method="POST">
                        <br>sec code:<input type="text" name="kaptchafield"><br />
                        <input type="submit" name="submit">
                    </form>
                </td>
            </tr>
        </table>
        <%
            String c = (String)session.getAttribute(com.google.code.kaptcha.Constants.KAPTCHA_SESSION_KEY);
            String parm = (String) request.getParameter("kaptchafield");
            out.println("Parameter: " + parm + " ? Session Key: " + c + " : ");
            if (c != null && parm != null) {
                if (c.equals(parm)) {
                    out.println("<b>true</b>");
                } else {
                    out.println("<b>false</b>");
                }
            }
        %>
    </body>
</html>
```

## 通过 WebService 请求
如果作为 WebService  项目，则无法简单的通过 `img src="kaptcha.jpg"`  来获取验证码图片，而是需要前端主动发起一次请求，而后台则是需要将图片写入 `HttpServletResponse` 。

### 后台配置
使用该方法，则不再需要配置 web.xml 。
我的项目是 Spring + cxf  的 WebService  项目，以此为例。首先 Spring  项目，需要配置 KaptchaProducer bean ，其次需要为 WebService  项目接口。
```XML
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:jaxrs="http://cxf.apache.org/jaxrs"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-4.0.xsd http://cxf.apache.org/jaxrs http://cxf.apache.org/schemas/jaxrs.xsd">

    <jaxrs:server id="captcha" address="/captcha">
        <jaxrs:serviceBeans>
            <ref bean="captchaService"/>
        </jaxrs:serviceBeans>
    </jaxrs:server>

    <bean id="captchaProducer" class="com.google.code.kaptcha.impl.DefaultKaptcha">
        <property name="config">
            <bean class="com.google.code.kaptcha.util.Config">
                <constructor-arg>
                    <props>
                        <!-- Kaptcha 配置 -->
                        <prop key="kaptcha.border">no</prop>
                        <prop key="kaptcha.image.width">250</prop>
                        <prop key="kaptcha.textproducer.font.size">80</prop>
                        <prop key="kaptcha.image.height">90</prop>
                        <prop key="kaptcha.session.key">code</prop>
                        <prop key="kaptcha.textproducer.char.length">4</prop>
                    </props>
                </constructor-arg>
            </bean>
        </property>
    </bean>
</beans>
```

然后编写验证码接口实现，生成验证码需要一个对应到会话的唯一的 ID，可以使用 token 或者 uuid  等，在缓存中，该 ID 将作为 Map  的 Key 。
```Java
@Path(value = "/")
@WebService
//@Produces(value = MediaType.APPLICATION_JSON)
public interface CaptchaService {
    @GET
    @Path(value = "gen")
    void genCaptcha(@Context HttpServletRequest request,
                    @Context HttpServletResponse response,
                    @QueryParam("token") String token) throws IOException;

}
/////////////////////////////////////////////////////////////////////////////////
@Component(value = "captchaService")
public class CaptchaServiceImpl implements CaptchaService {
    private    @Value("${cache.captchaexpire}") int EXPIRE = 5;

    @Override
    public void genCaptcha(HttpServletRequest request, HttpServletResponse response, String token) throws IOException {
        String capText;
        capText = CaptchaUtil.gen(request, response);
        // 自定义的缓存，保存图片验证码，保存 5 min 有效
        SessionCacheManager.getInstance().add(token, CacheKey.CAPTCHA_PC, capText, EXPIRE * 60 * 1000, false);
    }

    /**
     * 采用了 Google 提供的 Kaptcha 验证码库生成验证码
     *
     * @param request  HttpServletRequest 请求
     * @param response HttpServletResponse 返回，用于输出验证码图片流
     */
    private static String gen(HttpServletRequest request,
                             HttpServletResponse response) throws IOException {
        response.setDateHeader("Expires", 0);
        // Set standard HTTP/1.1 no-cache headers.
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        // Set IE extended HTTP/1.1 no-cache headers (use addHeader).
        response.addHeader("Cache-Control", "post-check=0, pre-check=0");
        // Set standard HTTP/1.0 no-cache header.
        response.setHeader("Pragma", "no-cache");
        // return a jpeg
        response.setContentType("image/jpeg");
        // p3p 跨域
        response.setHeader("P3P", "CP='IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT'");

        // create the text for the image
        String capText = captchaProducer.createText();
        // store the text in the session
        request.getSession().setAttribute(Constants.KAPTCHA_SESSION_KEY, capText);

        // create the image with the text
        BufferedImage bi = captchaProducer.createImage(capText);
        ServletOutputStream out = response.getOutputStream();
        // write the data out
        ImageIO.write(bi, "jpg", out);
        try {
            out.flush();
        } finally {
            out.close();
        }
        return capText;
    }
}
```

### 前端请求
前端在获得 token  后，再发起 webservice  请求。改变 img src  后，返回的图片将直接显示。
```html
<script type="application/javascript">
    document.getElementById('captcha').src=URL+"/captcha/gen?token="+encodeURIComponent(token)+"&r="+Math.random();

    function refresh() {
        document.getElementById('captcha')
            .src=URL+"/captcha/gen?token="+encodeURIComponent(token)+"&r="+Math.random();
    }
</script>
<img id="captcha" style="vertical-align: middle;" title="点击更换" src="" alt="未预登录，无验证图片" height="40" width="85" onclick="refresh();">
```

### 后台验证
因为在生成验证码时，已经将验证码写入了缓存，此处校验只需要从缓存取出验证码，与前端传入的验证码相比较即可。

# Kaptcha 配置

| 属性                               | 说明                 | 默认值                                      |
| -------------------------------- | ------------------ | ---------------------------------------- |
| kaptcha.border                   | 是否有边框,可以自己设置yes，no | 默认为true                                  |
| kaptcha.border.color             | 边框颜色               | 默认为Color.BLACK                           |
| kaptcha.border.thickness         | 边框粗细度              | 默认为1                                     |
| kaptcha.producer.impl            | 验证码生成器             | 默认为DefaultKaptcha                        |
| kaptcha.textproducer.impl        | 验证码文本生成器           | 默认为DefaultTextCreator                    |
| kaptcha.textproducer.char.string | 验证码文本字符内容范围        | 默认为abcde2345678gfynmnpwx                 |
| kaptcha.textproducer.char.length | 验证码文本字符长度          | 默认为5                                     |
| kaptcha.textproducer.font.names  | 验证码文本字体样式          | 默认为new  Font("Arial", 1, fontSize), new Font("Courier", 1,  fontSize) |
| kaptcha.textproducer.font.size   | 验证码文本字符大小          | 默认为40                                    |
| kaptcha.textproducer.font.color  | 验证码文本字符颜色          | 默认为Color.BLACK                           |
| kaptcha.textproducer.char.space  | 验证码文本字符间距          | 默认为2                                     |
| kaptcha.noise.impl               | 验证码噪点生成对象          | 默认为DefaultNoise                          |
| kaptcha.noise.color              | 验证码噪点颜色            | 默认为Color.BLACK                           |
| kaptcha.obscurificator.impl      | 验证码样式引擎            | 默认为WaterRipple                           |
| kaptcha.word.impl                | 验证码文本字符渲染          | 默认为DefaultWordRenderer                   |
| kaptcha.background.impl          | 验证码背景生成器           | 默认为DefaultBackground                     |
| kaptcha.background.clear.from    | 验证码背景颜色渐进          | 默认为Color.LIGHT_GRAY                      |
| kaptcha.background.clear.to      | 验证码背景颜色渐进          | 默认为Color.WHITE                           |
| kaptcha.image.width              | 验证码图片宽度            | 默认为200                                   |
| kaptcha.image.height             | 验证码图片高度            | 默认为50                                    |

# 参考资料
1. Kaptcha 官网，https://code.google.com/archive/p/kaptcha/
2. java web项目生成验证码的解决方案，作者 夜空中苦逼的程序员， http://blog.csdn.net/chenghui0317/article/details/12526439
3. java使用kaptcha 验证码组件，作者 代码如疯， http://blog.csdn.net/mdcmy/article/details/7733796

