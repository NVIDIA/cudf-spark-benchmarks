
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2 
            WHERE p2.p_size > 10
        )
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    rs.o_orderkey,
    rs.o_orderdate,
    rs.rank,
    p.p_partkey,
    p.p_name,
    s.s_name,
    ss.total_parts,
    ss.total_value,
    COALESCE(MAX(l.l_discount), 0) AS max_discount,
    CASE 
        WHEN rs.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    ranked_orders rs
JOIN 
    lineitem l ON rs.o_orderkey = l.l_orderkey
LEFT JOIN 
    filtered_parts p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    supplier_summary ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    rs.rank <= 10
GROUP BY 
    rs.o_orderkey, rs.o_orderdate, rs.rank, p.p_partkey, p.p_name, s.s_name, ss.total_parts, ss.total_value, rs.o_totalprice
ORDER BY 
    rs.o_orderdate DESC, rs.rank;
