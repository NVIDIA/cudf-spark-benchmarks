WITH  sales_summary AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-10-01'
    GROUP BY 
        l_orderkey
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(ss.total_sales) AS total_sales
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        sales_summary ss ON o.o_orderkey = ss.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
    HAVING 
        SUM(ss.total_sales) > 10000
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 500
    GROUP BY 
        s.s_suppkey, s.s_name
),
combined_summary AS (
    SELECT 
        h.o_orderkey,
        h.o_orderdate,
        h.o_totalprice,
        h.c_name,
        COALESCE(t.total_supply_cost, 0) AS total_supply_cost
    FROM 
        high_value_orders h
    LEFT JOIN 
        top_suppliers t ON h.o_orderkey = t.s_suppkey 
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.o_totalprice) AS total_order_value,
    MAX(co.total_supply_cost) AS max_supply_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    combined_summary co ON o.o_orderkey = co.o_orderkey
WHERE 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    c.c_name
ORDER BY 
    total_order_value DESC
LIMIT 10;