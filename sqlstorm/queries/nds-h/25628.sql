WITH filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10 
        AND p.p_retailprice BETWEEN 50.00 AND 200.00
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
recent_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        c.c_name AS customer_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-31'
)
SELECT 
    f.p_name,
    f.p_brand,
    f.p_size,
    f.p_retailprice,
    s.s_name,
    s.nation_name,
    o.o_totalprice,
    o.o_orderdate,
    o.customer_name
FROM 
    filtered_parts f
JOIN 
    partsupp ps ON f.p_partkey = ps.ps_partkey
JOIN 
    supplier_details s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    recent_orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    f.p_comment LIKE '%high%'
ORDER BY 
    f.p_retailprice DESC, 
    o.o_orderdate DESC
LIMIT 50;