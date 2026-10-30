WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        r.r_name AS region_name,
        SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_comment,
        LENGTH(s.s_comment) AS comment_length
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
        CONCAT(p.p_mfgr, ': ', p.p_name, ' [', p.p_type, ']') AS full_description
    FROM 
        part p
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(li.l_orderkey) AS item_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    si.s_name,
    si.region_name,
    pi.full_description,
    os.o_orderkey,
    os.o_orderdate,
    os.item_count,
    os.total_revenue,
    CASE 
        WHEN os.total_revenue > 5000 THEN 'High Value'
        WHEN os.total_revenue BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS revenue_category
FROM 
    supplier_info si
JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN 
    part_info pi ON ps.ps_partkey = pi.p_partkey
JOIN 
    order_summary os ON pi.p_partkey = os.o_orderkey
WHERE 
    si.comment_length > 50
ORDER BY 
    os.total_revenue DESC, si.s_name;
