
WITH sales_summary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
abnormal_orders AS (
    SELECT 
        ss.o_orderkey,
        ss.total_sales,
        ss.unique_customers,
        CASE 
            WHEN ss.sales_rank = 1 AND ss.total_sales IS NOT NULL THEN 'Top Sales Order'
            ELSE 'Regular Order'
        END AS order_type
    FROM 
        sales_summary ss
),
supplier_statistics AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
nation_supplier AS (
    SELECT 
        n.n_name,
        s.s_name,
        COALESCE(ss.total_supply_value, 0) AS total_supply_value
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        supplier_statistics ss ON s.s_suppkey = ss.ps_suppkey
)
SELECT 
    ns.n_name,
    ns.s_name,
    ns.total_supply_value,
    ao.total_sales,
    ao.unique_customers
FROM 
    nation_supplier ns
LEFT JOIN 
    abnormal_orders ao ON ao.o_orderkey = (SELECT MAX(o_orderkey) FROM abnormal_orders)
WHERE 
    ns.total_supply_value > (
        SELECT AVG(total_supply_value) FROM nation_supplier
    )
ORDER BY 
    ns.total_supply_value DESC, 
    ao.total_sales DESC NULLS LAST;
