WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 YEAR'
),
ActiveSuppliers AS (
    SELECT 
        DISTINCT l.l_suppkey
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '6 MONTH'
)
SELECT 
    c.c_name,
    cs.total_orders,
    cs.total_spent,
    si.s_name,
    si.total_cost,
    si.avg_acctbal,
    CASE 
        WHEN cs.total_spent >= 1000 THEN 'High Value'
        WHEN cs.total_spent < 100 THEN 'Low Value'
        ELSE 'Medium Value'
    END AS customer_segment,
    ro.order_rank
FROM 
    CustomerOrderSummary cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierInfo si ON si.total_cost IS NOT NULL
JOIN 
    RankedOrders ro ON ro.o_orderkey = cs.total_orders
WHERE 
    c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA'))
AND 
    si.s_suppkey IN (SELECT * FROM ActiveSuppliers)
ORDER BY 
    cs.total_spent DESC, c.c_name;