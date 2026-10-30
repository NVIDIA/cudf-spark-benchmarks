
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CUME_DIST() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), high_value_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM 
        ranked_orders ro
    WHERE 
        ro.price_rank <= 0.1
), supplier_part_details AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), order_lines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    h.o_orderkey,
    SUM(pd.p_retailprice * pd.ps_availqty) AS estimated_value,
    COUNT(DISTINCT l.l_orderkey) AS total_lines
FROM 
    high_value_orders h
JOIN 
    lineitem l ON h.o_orderkey = l.l_orderkey
JOIN 
    supplier_part_details pd ON pd.ps_partkey = l.l_partkey
GROUP BY 
    h.o_orderkey
HAVING 
    SUM(pd.p_retailprice * pd.ps_availqty) > 10000
ORDER BY 
    estimated_value DESC;
