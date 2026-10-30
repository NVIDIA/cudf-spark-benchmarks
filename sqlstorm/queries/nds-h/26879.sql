WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LENGTH(s.s_comment) AS comment_length,
        UPPER(s.s_name) AS upper_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
part_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_brand,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS part_comment_length,
        CONCAT(p.p_name, ' - ', p.p_brand) AS part_details
    FROM 
        part p
),
order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice 
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    pi.p_name,
    pi.part_details,
    od.o_orderkey,
    od.o_orderdate,
    od.o_totalprice,
    od.line_count,
    od.total_extended_price,
    sd.comment_length,
    pi.part_comment_length
FROM 
    supplier_details sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    part_info pi ON ps.ps_partkey = pi.p_partkey
JOIN 
    order_details od ON pi.p_partkey = od.o_orderkey
WHERE 
    sd.comment_length > 50 
    AND pi.part_comment_length < 20
ORDER BY 
    sd.nation_name, od.o_orderdate DESC, pi.p_retailprice DESC
LIMIT 100;
