CREATE OR REPLACE FUNCTION PARSE_XML(raw_file_id bigint) RETURNS VARCHAR
    LANGUAGE plpgsql
AS $$
BEGIN
    with ins_base as (
        insert into base_data
            select nextval('base_data_seq'),
                   NOW(),
                   (select id from raw_file order by id desc limit 1),
                   unnest(xpath('WelcomePictureName/text()', base_data::xml))::varchar          welcome_picture_name,
                   unnest(xpath('AppVersion/text()', base_data::xml))::varchar                  app_version,
                   unnest(xpath('SaveDateTime/text()', base_data::xml))::text::timestamp        save_date_time,
                   unnest(xpath('PerformanceDateTime/text()', base_data::xml))::text::timestamp performance_date_time,
                   unnest(xpath('RiskDateTime/text()', base_data::xml))::text::timestamp        risk_date_time,
                   unnest(xpath('ForceUpdate/text()', base_data::xml))::text::smallint          force_update
            from ((select unnest(xpath('/BaseData', data::xml)) as base_data from raw_file where id = raw_file_id)) temp
            returning id
    ), system_parameter_xml as (
        select nextval('system_parameter_seq') system_parameter_pk,
               unnest(xpath('/BaseData/SystemParameter', data::xml)) system_parameters from raw_file
    ), ins_sys_param as (
        insert into system_parameter
            select system_parameter_pk,
                   NOW(),
                   (select id from ins_base)
            from (select system_parameter_pk from system_parameter_xml) temp
    ), GeoLocationList_xml as (
        select nextval('geo_location_list_seq') geo_location_list_pk,
               system_parameter_pk,
               unnest(xpath('GeoLocationList', system_parameters::xml)) GeoLocationLists from system_parameter_xml
    ), ins_geolocation_list as (
        insert into geo_location_list
            select geo_location_list_pk,
                   NOW(),
                   system_parameter_pk
            from GeoLocationList_xml
    ), GeoLocation_xml as (
        select
            geo_location_pk,
            geo_location_list_pk,
            unnest(xpath('ProductLine', GeoLocation::xml)) product_line_el,
            unnest(xpath('ClientDomicile', GeoLocation::xml)) client_domicile_el,
            unnest(xpath('GeoLocationIso', GeoLocation::xml)) geo_location_iso_el,
            unnest(xpath('EnforceLocationCheck', GeoLocation::xml)) enforce_location_check_el
        from (select nextval('geo_location_seq') geo_location_pk,
                     geo_location_list_pk,
                     unnest(xpath('GeoLocation', GeoLocationLists::xml)) GeoLocation from GeoLocationList_xml) temp
    ), ins_geolocation as (
        insert into geo_location
            select
                geo_location_pk id,
                NOW() created,
                geo_location_list_pk,
                unnest(xpath('string()', product_line_el::text::xml))::text::smallint product_line,
                unnest(xpath('string()', client_domicile_el::text::xml))::text::smallint client_domicile,
                unnest(xpath('string()', geo_location_iso_el::text::xml))::text::varchar geo_location_iso,
                unnest(xpath('string()', enforce_location_check_el::text::xml))::text::boolean enforce_location_check
            from GeoLocation_xml temp
    ), ClientLanguageList_xml as (
        select nextval('client_language_list_seq') client_language_list_pk,
               system_parameter_pk,
               unnest(xpath('ClientLanguageList', system_parameters::xml)) GeoLocationLists from system_parameter_xml
    ), ins_client_language_list as (
        insert into client_language_list
            select client_language_list_pk,
                   NOW(),
                   system_parameter_pk
            from ClientLanguageList_xml
    ), ClientLanguage_xml as (
        select
            client_language_pk,
            client_language_list_pk,
            unnest(xpath('ProductLine', ClientLanguage::text::xml)) product_line_el,
            unnest(xpath('ClientDomicile', ClientLanguage::text::xml)) client_domicile_el,
            unnest(xpath('LanguageId', ClientLanguage::text::xml)) language_id_el
        from (select nextval('client_language_seq') client_language_pk,
                     client_language_list_pk,
                     unnest(xpath('ClientLanguage', GeoLocationLists::xml)) ClientLanguage from ClientLanguageList_xml) temp
    ), ins_client_language as (
        insert into client_language
            select
                client_language_pk id,
                NOW() created,
                client_language_list_pk,
                unnest(xpath('string()', product_line_el::text::xml))::text::smallint product_line,
                unnest(xpath('string()', client_domicile_el::text::xml))::text::smallint client_domicile,
                unnest(xpath('string()', language_id_el::text::xml))::text::smallint language_id
            from ClientLanguage_xml temp
    ), product_parameter_xml as (
        select nextval('product_parameter_seq') product_parameter_pk,
               unnest(xpath('/BaseData/ProductParameter', data::xml)) product_parameter from raw_file
    ), ins_product_parameter as (
        insert into product_parameter
            select product_parameter_pk id,
                   NOW(),
                   (select id from ins_base)
            from (select product_parameter_pk from product_parameter_xml) temp
    ), ProductLineList_xml as (
        select nextval('product_line_list_seq') product_line_list_pk,
               product_parameter_pk,
               unnest(xpath('ProductLineList', product_parameter::xml)) ProductLineList from product_parameter_xml
    ), ins_product_line_list as (
        insert into product_line_list
            select product_line_list_pk,
                   NOW(),
                   product_parameter_pk
            from ProductLineList_xml
    ), ProductLine_xml as (
        select
            product_line_pk,
            product_line_list_pk,
            unnest(xpath('Id', ProductLine::text::xml)) external_id_el,
            unnest(xpath('LookupId', ProductLine::text::xml)) lookup_id_el,
            unnest(xpath('ShortName', ProductLine::text::xml)) short_name_el,
            unnest(xpath('SortRank', ProductLine::text::xml)) sort_rank_el,
            unnest(xpath('LanguageLabelList', ProductLine::text::xml)) language_label_list_el
        from (select nextval('product_line_seq') product_line_pk,
                     product_line_list_pk,
                     unnest(xpath('ProductLine', ProductLineList::xml)) ProductLine from ProductLineList_xml) temp
    ), ins_product_line as (
        insert into product_line
            select
                product_line_pk,
                NOW(),
                product_line_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', lookup_id_el::text::xml))::text::varchar lookup_id,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name,
                unnest(xpath('text()', sort_rank_el::text::xml))::text::smallint sort_rank
            from ProductLine_xml
    ), ProductLineLanguageLabelList_xml as (
        select nextval('product_line_language_label_list_seq') product_line_language_label_list_pk,
               product_line_pk,
               language_label_list_el from ProductLine_xml
    ), ins_product_line_language_label_list as (
        insert into product_line_language_label_list
            select product_line_language_label_list_pk,
                   NOW(),
                   product_line_pk
            from (select product_line_language_label_list_pk, product_line_pk from ProductLineLanguageLabelList_xml) temp
    ), ProductLineLanguageLabelXml as (
        select
            product_line_language_label_pk,
            product_line_language_label_list_pk,
            unnest(xpath('Id', ProductLineLanguageLabel::xml)) id_el,
            unnest(xpath('LanguageId', ProductLineLanguageLabel::xml)) language_id_el,
            unnest(xpath('LabelText', ProductLineLanguageLabel::xml)) label_text_el
        from (select nextval('product_line_language_label_seq') product_line_language_label_pk,
                     product_line_language_label_list_pk,
                     unnest(xpath('LanguageLabel', language_label_list_el::xml)) ProductLineLanguageLabel
              from ProductLineLanguageLabelList_xml) temp
    ), ins_product_line_language_label as (
        insert into product_line_language_label
            select
                product_line_language_label_pk,
                NOW(),
                product_line_language_label_list_pk,
                unnest(xpath('string()', id_el::xml))::text::bigint external_id,
                unnest(xpath('string()', language_id_el::xml))::text::smallint language_id,
                unnest(xpath('string()', label_text_el::xml))::text::varchar label_text
            from ProductLineLanguageLabelXml
    ), ClientDomicileList_xml as (
        select nextval('client_domicile_list_seq') client_domicile_list_pk,
               product_parameter_pk,
               unnest(xpath('ClientDomicileList', product_parameter::xml)) ClientDomicileList from product_parameter_xml
    ), ins_client_domicile_list as (
        insert into client_domicile_list
            select client_domicile_list_pk,
                   NOW(),
                   product_parameter_pk
            from ClientDomicileList_xml
    ), ClientDomicile_xml as (
        select
            client_domicile_pk,
            client_domicile_list_pk,
            unnest(xpath('Id', ClientDomicile::text::xml)) external_id_el,
            unnest(xpath('LookupId', ClientDomicile::text::xml)) lookup_id_el,
            unnest(xpath('ShortName', ClientDomicile::text::xml)) short_name_el,
            unnest(xpath('LanguageLabelList', ClientDomicile::text::xml)) language_label_list_el
        from (select nextval('client_domicile_seq') client_domicile_pk,
                     client_domicile_list_pk,
                     unnest(xpath('ClientDomicile', ClientDomicileList::xml)) ClientDomicile from ClientDomicileList_xml) temp
    ), ins_client_domicile as (
        insert into client_domicile
            select
                client_domicile_pk,
                NOW(),
                client_domicile_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', lookup_id_el::text::xml))::text::varchar lookup_id,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name
            from ClientDomicile_xml
    ), ClientDomicileLanguageLabelList_xml as (
        select nextval('client_domicile_language_label_list_seq') client_domicile_language_label_list_pk,
               client_domicile_pk,
               language_label_list_el from ClientDomicile_xml
    ), ins_client_domicile_language_label_list as (
        insert into client_domicile_language_label_list
            select client_domicile_language_label_list_pk,
                   NOW(),
                   client_domicile_pk
            from ClientDomicileLanguageLabelList_xml
    ), ClientDomicileLanguageLabelXml as (
        select
            client_domicile_language_label_pk,
            client_domicile_language_label_list_pk,
            unnest(xpath('Id', ClientDomicileLanguageLabel::xml)) id_el,
            unnest(xpath('LanguageId', ClientDomicileLanguageLabel::xml)) language_id_el,
            unnest(xpath('LabelText', ClientDomicileLanguageLabel::xml)) label_text_el
        from (select nextval('client_domicile_language_label_seq') client_domicile_language_label_pk,
                     client_domicile_language_label_list_pk,
                     unnest(xpath('LanguageLabel', language_label_list_el::xml)) ClientDomicileLanguageLabel
              from ClientDomicileLanguageLabelList_xml) temp
    ), ins_client_domicile_language_label as (
        insert into client_domicile_language_label
            select
                client_domicile_language_label_pk,
                NOW(),
                client_domicile_language_label_list_pk,
                unnest(xpath('string()', id_el::xml))::text::bigint external_id,
                unnest(xpath('string()', language_id_el::xml))::text::smallint language_id,
                unnest(xpath('string()', label_text_el::xml))::text::varchar label_text
            from ClientDomicileLanguageLabelXml
    ), RiskProfileListXml as (
        select nextval('risk_profile_list_seq') risk_profile_list_pk,
               product_parameter_pk,
               unnest(xpath('RiskProfileList', product_parameter::xml)) RiskProfileList from product_parameter_xml
    ), ins_risk_profile_list as (
        insert into risk_profile_list
            select risk_profile_list_pk,
                   NOW(),
                   product_parameter_pk
            from RiskProfileListXml
    ), RiskProfileXml as (
        select
            risk_profile_pk,
            risk_profile_list_pk,
            unnest(xpath('Id', RiskProfile::text::xml)) external_id_el,
            unnest(xpath('LookupId', RiskProfile::text::xml)) lookup_id_el,
            unnest(xpath('ShortName', RiskProfile::text::xml)) short_name_el,
            unnest(xpath('SortRank', RiskProfile::text::xml)) sort_rank_el,
            unnest(xpath('LanguageLabelList', RiskProfile::text::xml)) language_label_list_el
        from (select nextval('risk_profile_seq') risk_profile_pk,
                     risk_profile_list_pk,
                     unnest(xpath('RiskProfile', RiskProfileList::xml)) RiskProfile from RiskProfileListXml) temp
    ), ins_risk_profile as (
        insert into risk_profile
            select
                risk_profile_pk,
                NOW(),
                risk_profile_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', lookup_id_el::text::xml))::text::varchar lookup_id,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name,
                unnest(xpath('text()', sort_rank_el::text::xml))::text::smallint sort_rank
            from RiskProfileXml
    ), RiskProfileLanguageLabelListXml as (
        select nextval('risk_profile_language_label_list_seq') risk_profile_language_label_list_pk,
               risk_profile_pk,
               language_label_list_el from RiskProfileXml
    ), ins_risk_profile_language_label_list as (
        insert into risk_profile_language_label_list
            select risk_profile_language_label_list_pk,
                   NOW(),
                   risk_profile_pk
            from RiskProfileLanguageLabelListXml
    ), RiskProfileLanguageLabelXml as (
        select
            risk_profile_language_label_pk,
            risk_profile_language_label_list_pk,
            unnest(xpath('Id', RiskProfileLanguageLabel::xml)) id_el,
            unnest(xpath('LanguageId', RiskProfileLanguageLabel::xml)) language_id_el,
            unnest(xpath('LabelText', RiskProfileLanguageLabel::xml)) label_text_el
        from (select nextval('risk_profile_language_label_seq') risk_profile_language_label_pk,
                     risk_profile_language_label_list_pk,
                     unnest(xpath('LanguageLabel', language_label_list_el::xml)) RiskProfileLanguageLabel
              from RiskProfileLanguageLabelListXml) temp
    ), ins_risk_profile_language_label as (
        insert into risk_profile_language_label
            select
                risk_profile_language_label_pk,
                NOW(),
                risk_profile_language_label_list_pk,
                unnest(xpath('string()', id_el::xml))::text::bigint external_id,
                unnest(xpath('string()', language_id_el::xml))::text::smallint language_id,
                unnest(xpath('string()', label_text_el::xml))::text::varchar label_text
            from RiskProfileLanguageLabelXml
            returning *
    ), RefCcyListXml as (
        select nextval('ref_ccy_list_seq') ref_ccy_list_pk,
               product_parameter_pk,
               unnest(xpath('RefCcyList', product_parameter::xml)) RefCcyList from product_parameter_xml
    ), ins_ref_ccy_list as (
        insert into ref_ccy_list
            select ref_ccy_list_pk,
                   NOW(),
                   product_parameter_pk
            from RefCcyListXml
    ), RefCcyXml as (
        select
            ref_ccy_pk,
            ref_ccy_list_pk,
            unnest(xpath('Id', RefCcy::text::xml)) external_id_el,
            unnest(xpath('IsoCode', RefCcy::text::xml)) iso_code_el,
            unnest(xpath('ShortName', RefCcy::text::xml)) short_name_el,
            unnest(xpath('SortRank', RefCcy::text::xml)) sort_rank_el,
            unnest(xpath('LanguageLabelList', RefCcy::text::xml)) language_label_list_el
        from (select nextval('ref_ccy_seq') ref_ccy_pk,
                     ref_ccy_list_pk,
                     unnest(xpath('RefCcy', RefCcyList::xml)) RefCcy from RefCcyListXml) temp
    ), ins_ref_ccy as (
        insert into ref_ccy
            select
                ref_ccy_pk,
                NOW(),
                ref_ccy_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', iso_code_el::text::xml))::text::varchar iso_code,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name,
                unnest(xpath('text()', sort_rank_el::text::xml))::text::smallint sort_rank
            from RefCcyXml
    ), RefCcyLanguageLabelListXml as (
        select nextval('ref_ccy_language_label_list_seq') ref_ccy_language_label_list_pk,
               ref_ccy_pk,
               language_label_list_el from RefCcyXml
    ), ins_ref_ccy_language_label_list as (
        insert into ref_ccy_language_label_list
            select ref_ccy_language_label_list_pk,
                   NOW(),
                   ref_ccy_pk
            from RefCcyLanguageLabelListXml
    ), RefCcyLanguageLabelXml as (
        select
            ref_ccy_language_label_pk,
            ref_ccy_language_label_list_pk,
            unnest(xpath('Id', RefCcyLanguageLabel::xml)) id_el,
            unnest(xpath('LanguageId', RefCcyLanguageLabel::xml)) language_id_el,
            unnest(xpath('LabelText', RefCcyLanguageLabel::xml)) label_text_el
        from (select nextval('ref_ccy_language_label_seq') ref_ccy_language_label_pk,
                     ref_ccy_language_label_list_pk,
                     unnest(xpath('LanguageLabel', language_label_list_el::xml)) RefCcyLanguageLabel
              from RefCcyLanguageLabelListXml) temp
    ), ins_ref_ccy_language_label as (
        insert into ref_ccy_language_label
            select
                ref_ccy_language_label_pk,
                NOW(),
                ref_ccy_language_label_list_pk,
                unnest(xpath('string()', id_el::xml))::text::bigint external_id,
                unnest(xpath('string()', language_id_el::xml))::text::smallint language_id,
                unnest(xpath('string()', label_text_el::xml))::text::varchar label_text
            from RefCcyLanguageLabelXml
    ), AssetClassListXml as (
        select nextval('asset_class_list_seq') asset_class_list_pk,
               product_parameter_pk,
               unnest(xpath('AssetClassList', product_parameter::xml)) AssetClassList from product_parameter_xml
    ), ins_asset_class_list as (
        insert into asset_class_list
            select asset_class_list_pk,
                   NOW(),
                   product_parameter_pk
            from AssetClassListXml
    ), AssetClassXml as (
        select
            asset_class_pk,
            asset_class_list_pk,
            unnest(xpath('Id', AssetClass::text::xml)) external_id_el,
            unnest(xpath('LookupId', AssetClass::text::xml)) lookup_id_el,
            unnest(xpath('ShortName', AssetClass::text::xml)) short_name_el,
            unnest(xpath('SortRank', AssetClass::text::xml)) sort_rank_el,
            unnest(xpath('ColorCodeHex', AssetClass::text::xml)) color_code_hex_el,
            unnest(xpath('BackColorCodeHex', AssetClass::text::xml)) back_color_code_hex_el,
            unnest(xpath('LanguageLabelList', AssetClass::text::xml)) language_label_list_el
        from (select nextval('asset_class_seq') asset_class_pk,
                     asset_class_list_pk,
                     unnest(xpath('AssetClass', AssetClassList::xml)) AssetClass from AssetClassListXml) temp
    ), ins_asset_class as (
        insert into asset_class
            select
                asset_class_pk,
                NOW(),
                asset_class_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', lookup_id_el::text::xml))::text::bigint lookup_id,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name,
                unnest(xpath('text()', sort_rank_el::text::xml))::text::smallint sort_rank,
                unnest(xpath('text()', color_code_hex_el::text::xml))::char color_code_hex,
                unnest(xpath('text()', back_color_code_hex_el::text::xml))::char back_color_code_hex
            from AssetClassXml
    ), AssetClassLanguageLabelListXml as (
        select nextval('asset_class_language_label_list_seq') asset_class_language_label_list_pk,
               asset_class_pk,
               language_label_list_el from AssetClassXml
    ), ins_asset_class_language_label_list as (
        insert into asset_class_language_label_list
            select asset_class_language_label_list_pk,
                   NOW(),
                   asset_class_pk
            from AssetClassLanguageLabelListXml
    ), AssetClassLanguageLabelXml as (
        select
            asset_class_language_label_pk,
            asset_class_language_label_list_pk,
            unnest(xpath('Id', AssetClassLanguageLabel::xml)) id_el,
            unnest(xpath('LanguageId', AssetClassLanguageLabel::xml)) language_id_el,
            unnest(xpath('LabelText', AssetClassLanguageLabel::xml)) label_text_el
        from (select nextval('asset_class_language_label_seq') asset_class_language_label_pk,
                     asset_class_language_label_list_pk,
                     unnest(xpath('LanguageLabel', language_label_list_el::xml)) AssetClassLanguageLabel
              from AssetClassLanguageLabelListXml) temp
    ), ins_asset_class_language_label as (
        insert into asset_class_language_label
            select
                asset_class_language_label_pk,
                NOW(),
                asset_class_language_label_list_pk,
                unnest(xpath('string()', id_el::xml))::text::bigint external_id,
                unnest(xpath('string()', language_id_el::xml))::text::smallint language_id,
                unnest(xpath('string()', label_text_el::xml))::text::varchar label_text
            from AssetClassLanguageLabelXml
    ), ProductParameterLanguageListXml as (
        select nextval('product_parameter_language_list_seq') product_parameter_language_list_pk,
               product_parameter_pk,
               unnest(xpath('LanguageList', product_parameter::xml)) LanguageList from product_parameter_xml
    ), ins_product_parameter_language_list as (
        insert into product_parameter_language_list
            select product_parameter_language_list_pk,
                   NOW(),
                   product_parameter_pk
            from ProductParameterLanguageListXml
    ), ProductParameterLanguageXml as (
        select
            product_parameter_language_pk,
            product_parameter_language_list_pk,
            unnest(xpath('Id', ProductLanguage::text::xml)) external_id_el,
            unnest(xpath('LookupId', ProductLanguage::text::xml)) lookup_id_el,
            unnest(xpath('ShortName', ProductLanguage::text::xml)) short_name_el,
            unnest(xpath('SortRank', ProductLanguage::text::xml)) sort_rank_el,
            unnest(xpath('Visible', ProductLanguage::text::xml)) visible_el
        from (select nextval('product_parameter_language_seq') product_parameter_language_pk,
                     product_parameter_language_list_pk,
                     unnest(xpath('Language', LanguageList::xml)) ProductLanguage from ProductParameterLanguageListXml) temp
    ), ins_product_parameter_language as (
        insert into product_parameter_language
            select
                product_parameter_language_pk,
                NOW(),
                product_parameter_language_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', lookup_id_el::text::xml))::text::varchar lookup_id,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name,
                unnest(xpath('text()', sort_rank_el::text::xml))::text::smallint sort_rank,
                unnest(xpath('text()', visible_el::text::xml))::text::bool visible
            from ProductParameterLanguageXml
    ), AllocBdwthListXml as (
        select nextval('alloc_bdwth_list_seq') alloc_bdwth_list_pk,
               product_parameter_pk,
               unnest(xpath('AllocBdwthList', product_parameter::xml)) AllocBdwthList from product_parameter_xml
    ), ins_alloc_bdwth_list as (
        insert into alloc_bdwth_list
            select alloc_bdwth_list_pk,
                   NOW(),
                   product_parameter_pk
            from AllocBdwthListXml
    ), AllocBdwthXml as (
        select
            alloc_bdwth_pk,
            alloc_bdwth_list_pk,
            unnest(xpath('Id', AllocBdwth::text::xml)) external_id_el_el,
            unnest(xpath('RiskProfileId', AllocBdwth::text::xml)) risk_profile_id_el,
            unnest(xpath('AssetClassId', AllocBdwth::text::xml)) asset_class_id_el,
            unnest(xpath('WgtMin', AllocBdwth::text::xml)) wgt_min_el,
            unnest(xpath('WgtMax', AllocBdwth::text::xml)) wgt_max_el
        from (select nextval('alloc_bdwth_seq') alloc_bdwth_pk,
                     alloc_bdwth_list_pk,
                     unnest(xpath('AllocBdwth', AllocBdwthList::xml)) AllocBdwth from AllocBdwthListXml) temp
    ), ins_alloc_bdwth as (
        insert into alloc_bdwth
            select
                alloc_bdwth_pk,
                NOW(),
                alloc_bdwth_list_pk,
                unnest(xpath('text()', external_id_el_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', risk_profile_id_el::text::xml))::text::bigint risk_profile_id,
                unnest(xpath('text()', asset_class_id_el::text::xml))::text::integer asset_class_id,
                unnest(xpath('text()', wgt_min_el::text::xml))::text::integer wgt_min,
                unnest(xpath('text()', wgt_max_el::text::xml))::text::integer wgt_max
            from AllocBdwthXml
    ), ConcentrationLimitsXml as (
        select
            concentration_limits_pk,
            product_parameter_pk,
            unnest(xpath('BulkLimit', ConcentrationLimits::text::xml)) bulk_limit_el,
            unnest(xpath('IssuerLimit', ConcentrationLimits::text::xml)) issuer_limit_el,
            unnest(xpath('SOMEINSIssuerLimit', ConcentrationLimits::text::xml)) SOMEINS_issuer_limit_el,
            unnest(xpath('SOMEINSIssuerId', ConcentrationLimits::text::xml)) SOMEINS_issuerId_el,
            unnest(xpath('FundBulkLimit', ConcentrationLimits::text::xml)) fund_bulk_limit_el,
            unnest(xpath('FundBulkIssuerName', ConcentrationLimits::text::xml)) fund_bulk_issuer_name_el
        from (select nextval('concentration_limits_seq') concentration_limits_pk,
                     product_parameter_pk,
                     unnest(xpath('ConcentrationLimits', product_parameter::xml)) ConcentrationLimits from product_parameter_xml) temp
    ), ins_concentration_limits as (
        insert into concentration_limits
            select
                concentration_limits_pk,
                NOW(),
                product_parameter_pk,
                unnest(xpath('text()', bulk_limit_el::text::xml))::text::integer bulk_limit,
                unnest(xpath('text()', issuer_limit_el::text::xml))::text::integer issuer_limit,
                unnest(xpath('text()', SOMEINS_issuer_limit_el::text::xml))::text::integer SOMEINS_issuer_limit,
                unnest(xpath('text()', SOMEINS_issuerId_el::text::xml))::varchar SOMEINS_issuerId,
                unnest(xpath('text()', fund_bulk_limit_el::text::xml))::text::integer fund_bulk_limit,
                unnest(xpath('text()', fund_bulk_issuer_name_el::text::xml))::varchar fund_bulk_issuer_name
            from ConcentrationLimitsXml
    ), ModuleAttributeListXml as (
        select nextval('module_attribute_list_seq') module_attribute_list_pk,
               product_parameter_pk,
               unnest(xpath('ModuleAttributeList', product_parameter::xml)) ModuleAttributeList from product_parameter_xml
    ), ins_module_attribute_list as (
        insert into module_attribute_list
            select module_attribute_list_pk,
                   NOW(),
                   product_parameter_pk
            from ModuleAttributeListXml
    ), ModuleAttributeXml as (
        select
            module_attribute_pk,
            module_attribute_list_pk,
            unnest(xpath('Id', ModuleAttribute::text::xml)) external_id_el,
            unnest(xpath('ShortName', ModuleAttribute::text::xml)) short_name_el,
            unnest(xpath('LanguageLabelList', ModuleAttribute::text::xml)) language_label_list_el,
            unnest(xpath('ModuleAttributeValueList', ModuleAttribute::text::xml)) module_attribute_value_list_el
        from (select nextval('module_attribute_seq') module_attribute_pk,
                     module_attribute_list_pk,
                     unnest(xpath('ModuleAttribute', ModuleAttributeList::xml)) ModuleAttribute from ModuleAttributeListXml) temp
    ), ins_module_attribute as (
        insert into module_attribute
            select
                module_attribute_pk,
                NOW(),
                module_attribute_list_pk,
                unnest(xpath('text()', external_id_el::text::xml))::text::bigint external_id,
                unnest(xpath('text()', short_name_el::text::xml))::varchar short_name
            from ModuleAttributeXml
    ), ModuleAttributeLanguageLabelListXml as (
        select nextval('module_attribute_language_label_list_seq') module_attribute_language_label_list_pk,
               module_attribute_pk,
               language_label_list_el LanguageList from ModuleAttributeXml
    ), ins_module_attribute_language_label_list as (
        insert into module_attribute_language_label_list
            select module_attribute_language_label_list_pk,
                   NOW(),
                   module_attribute_pk
            from ModuleAttributeLanguageLabelListXml
    ), ModuleAttributeLanguageLabelXml as (
        select
            module_attribute_language_label_pk,
            module_attribute_language_label_list_pk,
            unnest(xpath('LanguageId', LanguageLabel::text::xml)) language_id_el,
            unnest(xpath('LabelText', LanguageLabel::text::xml)) label_text_el
        from (select nextval('module_attribute_language_label_seq') module_attribute_language_label_pk,
                     module_attribute_language_label_list_pk,
                     unnest(xpath('LanguageLabel', LanguageList::xml)) LanguageLabel from ModuleAttributeLanguageLabelListXml) temp
    ), ins_module_attribute_language_label as (
        insert into module_attribute_language_label
            select
                module_attribute_language_label_pk,
                NOW(),
                module_attribute_language_label_list_pk,
                unnest(xpath('text()', language_id_el::text::xml))::text::smallint external_id,
                unnest(xpath('text()', label_text_el::text::xml))::text label_text
            from ModuleAttributeLanguageLabelXml
    ) UPDATE raw_file SET parsed = TRUE where id = raw_file_id;
    return 'done';
END
$$;