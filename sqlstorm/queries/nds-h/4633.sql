
WITH SupplierAggregate AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS line_count,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice) DESC) AS rn
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(SA.total_available, 0) AS supply_available,
    COALESCE(SA.total_supplycost, 0) AS supply_cost,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_spent, 0.00) AS total_spent,
    la.revenue,
    la.line_count,
    la.avg_quantity
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    SupplierAggregate SA ON co.c_custkey = SA.s_suppkey
JOIN 
    LineItemAnalysis la ON co.c_custkey = la.l_orderkey
WHERE 
    (co.c_custkey IS NULL OR SA.s_acctbal > 1000)
    AND (co.total_spent > 500 OR SA.total_available IS NOT NULL)
ORDER BY 
    co.c_custkey, la.revenue DESC;
