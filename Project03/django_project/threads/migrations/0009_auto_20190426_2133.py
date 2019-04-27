# Generated by Django 2.1.7 on 2019-04-27 01:33

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('threads', '0008_auto_20190423_2350'),
    ]

    operations = [
        migrations.CreateModel(
            name='Sub',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=200)),
                ('description', models.CharField(max_length=1000)),
            ],
        ),
        migrations.AddField(
            model_name='thread',
            name='sub',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='threads.Sub'),
            preserve_default=False,
        ),
    ]