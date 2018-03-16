{{ css('style/style') }}
{% include "../../_script/config.swig" %}

{# lightbox #}
{% if theme.lightbox %}
    {{ css('script/lib/lightbox/css/lightbox.min') }}
{% endif %}

{# animation #}
{% if theme.animate %}
    {{ css('syuanpi/syuanpi.min') }}
{% endif %}

{# favicon #}
{% if theme.favicon %}
    <link rel="icon" href="{{ theme.favicon }}">
{% endif %}

{# any analytics #}
{% include "../../_script/_analytics/google.swig" %}
{% include "../../_script/_analytics/baidu.swig" %}
{% include "../../_script/_analytics/busuanzi.swig" %}

<link href="https://cdn.bootcss.com/KaTeX/0.7.1/katex.min.css" rel="stylesheet">