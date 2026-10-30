WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COALESCE(ss.total_parts, 0) AS supplier_parts_count,
    COALESCE(co.avg_order_value, 0) AS customer_avg_order_value,
    tn.total_revenue
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = l.l_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'United States') LIMIT 1)
LEFT JOIN 
    TopNations tn ON tn.n_name = 'United States'  
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
GROUP BY 
    p.p_name, ss.total_parts, co.avg_order_value, tn.total_revenue
ORDER BY 
    revenue DESC
LIMIT 10;