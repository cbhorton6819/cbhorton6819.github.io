---
 layout: archive
 title: "Data Projects"
 permalink: /data_projects/
 author_profile: true
---

{% include base_path %}
{% include group-by-array collection=site.posts field="tags" %}

{% for tag in group_names %}
  <h2 id="{{ tag | slugify }}" class="archive__subtitle">{{ tag }}</h2>
  {% for post in group_items[tag] %}
    {% include archive-single.html %}
  {% endfor %}
{% endfor %}