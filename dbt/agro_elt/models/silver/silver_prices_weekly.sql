{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['week_start', 'state', 'product'],
    full_refresh=false,
    on_schema_change='fail'
) }}

select
  date_trunc(data_coleta, week(monday)) as week_start,
  sigla_uf as state,
  case produto when 'Etanol' then 'ethanol' when 'Gasolina' then 'gasoline' end as product,
  avg(preco_venda) as avg_price,
  approx_quantiles(preco_venda, 2)[offset(1)] as median_price,
  count(*) as n_obs,
  count(distinct cnpj_revenda) as n_stations
from {{ source('basedosdados', 'microdados') }}
where ano >= 2022
  and sigla_uf in ('SP', 'GO', 'MG', 'MS', 'PR')
  and produto in ('Etanol', 'Gasolina')
  and preco_venda between 1 and 20
{% if is_incremental() %}
  and data_coleta >= date_sub((select max(week_start) from {{ this }}), interval 28 day)
{% endif %}
group by 1, 2, 3