
WITH  price_per_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_stats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
          AND l.l_shipdate >= DATE '1997-01-01' 
          AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
customer_stats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.total_revenue) AS total_spent,
        COUNT(os.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        order_stats os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_performance AS (
    SELECT 
        p.p_brand,
        SUM(pp.total_cost) AS brand_cost,
        COUNT(DISTINCT pp.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        price_per_supplier pp ON p.p_partkey = pp.s_suppkey
    GROUP BY 
        p.p_brand
)

SELECT 
    cs.c_name,
    cs.total_spent,
    cs.orders_count,
    sp.brand_cost,
    sp.supplier_count
FROM 
    customer_stats cs
LEFT JOIN 
    supplier_performance sp ON cs.total_spent > sp.brand_cost
WHERE 
    cs.total_spent IS NOT NULL 
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
