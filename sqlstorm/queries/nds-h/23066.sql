WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
), 
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_custkey, 
        AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS avg_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
), 
AggregatedOrderData AS (
    SELECT 
        co.c_custkey, 
        COUNT(co.o_orderkey) AS order_count, 
        SUM(co.avg_price) AS total_spent
    FROM 
        CustomerOrders co
    JOIN 
        HighValueSuppliers hvs ON co.c_custkey = 
        (SELECT c.c_custkey 
         FROM customer c 
         WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
         LIMIT 1)
    GROUP BY 
        co.c_custkey
    HAVING 
        SUM(co.avg_price) > 1000
), 
FinalResults AS (
    SELECT 
        r.r_name, 
        AVG(a.total_spent) AS avg_spending
    FROM 
        AggregatedOrderData a
    JOIN 
        customer c ON a.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(a.c_custkey) > 5
)

SELECT 
    r.r_name, 
    COALESCE(f.avg_spending, 0) AS avg_spending
FROM 
    region r
LEFT JOIN 
    FinalResults f ON r.r_name = f.r_name
ORDER BY 
    r.r_name ASC NULLS FIRST;

