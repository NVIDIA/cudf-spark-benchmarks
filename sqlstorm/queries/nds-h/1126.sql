
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierStats AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    s.s_name,
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_orderkey) AS number_of_orders,
    COALESCE(cs.total_orders, 0) AS total_orders_by_customer,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    ss.total_supply_cost,
    ss.supplier_count,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders cs ON s.s_nationkey = cs.c_custkey
JOIN 
    SupplierStats ss ON l.l_partkey = ss.p_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-12-31'
GROUP BY 
    s.s_name, r.r_name, cs.total_orders, cs.total_spent, ss.total_supply_cost, ss.supplier_count
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM (SELECT 
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
    FROM 
        lineitem 
    WHERE 
        l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31' 
    GROUP BY 
        l_orderkey) AS overall_revenue)
ORDER BY 
    revenue_rank;
