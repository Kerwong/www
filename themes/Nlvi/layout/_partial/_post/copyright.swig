{% if theme.copyright.enable %}
  <hr class="copy-line">
  <div class="post-copyright">
    <div class="copy-author">
      <span>{{ __('copyright.author') }} :</span>
      <span>{{ config.author }}</span>
    </div>
    <div class="copy-url">
      <span>{{ __('copyright.url') }} :</span>
      <a href="{{ page.permalink }}">{{ page.permalink }}</a>
    </div>
    <div class="copy-origin">
      <span>{{ __('copyright.origin') }} :</span>
      <a href="{{ config.url }}">{{ config.url }}</a>
    </div>
    <div class="copy-license">
	  <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="知识共享许可协议" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/80x15.png" /></a> 本作品采用<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">知识共享署名-相同方式共享 4.0 国际许可协议</a>进行许可。
    </div>
  </div>
{% endif %}
