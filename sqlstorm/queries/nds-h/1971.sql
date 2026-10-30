
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_supplycost,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        cu.total_order_value
    FROM 
        customer c
    JOIN 
        CustomerOrders cu ON c.c_custkey = cu.c_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, l.l_partkey
)
SELECT 
    r.r_name,
    COALESCE(hc.c_name, 'No customer') AS customer_name,
    COALESCE(ss.s_name, 'No supplier') AS supplier_name,
    COALESCE(SUM(od.net_revenue), 0) AS total_revenue,
    COALESCE(AVG(rs.total_supplycost), 0) AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON ss.s_suppkey = rs.s_suppkey
LEFT JOIN 
    HighValueCustomers hc ON ss.s_nationkey = hc.c_custkey
LEFT JOIN 
    OrderDetails od ON ss.s_suppkey = od.l_partkey
GROUP BY 
    r.r_name, hc.c_name, ss.s_name
HAVING 
    SUM(od.net_revenue) > 100000 OR COUNT(hc.c_custkey) > 5
ORDER BY 
    total_revenue DESC, avg_supply_cost ASC;
