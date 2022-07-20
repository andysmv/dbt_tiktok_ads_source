with base as (

    select *
    from {{ ref('stg_tiktok_ads__ad_history_tmp') }}

), 

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_tiktok_ads__ad_history_tmp')),
                staging_columns=get_ad_history_columns()
            )
        }}

    from base

), 

final as (

    select  
        ad_id,
        cast(updated_at as {{ dbt_utils.type_timestamp() }}) as updated_at,
        adgroup_id as ad_group_id,
        advertiser_id,
        campaign_id,
        ad_name,
        ad_text,
        call_to_action,
        click_tracking_url,
        impression_tracking_url,
        {{ dbt_utils.split_part('landing_page_url', "'?'", 1) }} as base_url,
        {{ dbt_utils.get_url_host('landing_page_url') }} as url_host,
        '/' || {{ dbt_utils.get_url_path('landing_page_url') }} as url_path,
        {{ dbt_utils.get_url_parameter('landing_page_url', 'utm_source') }} as utm_source,
        {{ dbt_utils.get_url_parameter('landing_page_url', 'utm_medium') }} as utm_medium,
        {{ dbt_utils.get_url_parameter('landing_page_url', 'utm_campaign') }} as utm_campaign,
        {{ dbt_utils.get_url_parameter('landing_page_url', 'utm_content') }} as utm_content,
        {{ dbt_utils.get_url_parameter('landing_page_url', 'utm_term') }} as utm_term,
        landing_page_url,
        video_id,
        cast(_fivetran_synced as {{ dbt_utils.type_timestamp() }}) as _fivetran_synced
    from fields

), 

most_recent as (

    select 
        *,
        row_number() over (partition by ad_id order by updated_at desc) = 1 as is_most_recent_record
    from final

)

select * from most_recent