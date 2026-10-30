WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' | ', s.s_address, ' | ', n.n_name) AS supplier_details
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_mfgr, 
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        CASE 
            WHEN p.p_size > 20 THEN 'Large' 
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium' 
            ELSE 'Small' 
        END AS size_category
    FROM 
        part p
),
OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderstatus, 
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM 
        orders o
)
SELECT 
    si.supplier_details, 
    pi.p_name, 
    pi.size_category, 
    oi.o_totalprice, 
    oi.o_orderstatus, 
    MAX(pi.comment_length) AS max_comment_length
FROM 
    SupplierInfo si
JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN 
    PartInfo pi ON ps.ps_partkey = pi.p_partkey
JOIN 
    lineitem li ON pi.p_partkey = li.l_partkey
JOIN 
    OrderInfo oi ON li.l_orderkey = oi.o_orderkey
WHERE 
    oi.o_totalprice > 1000 AND 
    pi.size_category = 'Large'
GROUP BY 
    si.supplier_details, pi.p_name, pi.size_category, oi.o_totalprice, oi.o_orderstatus
ORDER BY 
    max_comment_length DESC, oi.o_totalprice DESC;
