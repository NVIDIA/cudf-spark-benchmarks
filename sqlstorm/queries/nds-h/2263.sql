
WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), HighestRevenue AS (
    SELECT 
        * 
    FROM 
        SupplierOrders
    WHERE 
        total_revenue = (SELECT MAX(total_revenue) FROM SupplierOrders)
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerStats
    WHERE 
        total_spent >= (SELECT AVG(total_spent) FROM CustomerStats)
), RegionAggregates AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(c.c_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    ra.r_name,
    h.s_name,
    h.total_revenue,
    t.c_name,
    t.total_spent,
    ra.total_account_balance
FROM 
    HighestRevenue h
JOIN 
    TopCustomers t ON t.total_orders > 5
JOIN 
    RegionAggregates ra ON ra.nation_count > 3
ORDER BY 
    h.total_revenue DESC, t.total_spent DESC;
