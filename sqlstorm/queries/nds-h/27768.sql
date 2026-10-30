WITH PartInfo AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_type, 
           RTRIM(UPPER(p.p_comment)) AS cleaned_comment 
    FROM part p
), 
SupplierInfo AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_phone, 
           SUBSTRING(s.s_address, 1, 20) AS short_address,
           s.s_comment 
    FROM supplier s
), 
CombinedInfo AS (
    SELECT pi.p_partkey, 
           pi.p_name, 
           si.s_name AS supplier_name, 
           si.short_address, 
           si.s_phone, 
           pi.cleaned_comment 
    FROM PartInfo pi
    JOIN partsupp ps ON pi.p_partkey = ps.ps_partkey
    JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
    WHERE LENGTH(pi.cleaned_comment) > 10
)
SELECT CONCAT('Part: ', ci.p_name, 
              ', Supplier: ', ci.supplier_name, 
              ', Address: ', ci.short_address, 
              ', Phone: ', ci.s_phone, 
              ', Comment: ', ci.cleaned_comment) AS string_output
FROM CombinedInfo ci
ORDER BY ci.p_name ASC
LIMIT 100;
