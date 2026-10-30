WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopCustomers AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_acctbal
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank = 1
),
CustomerSupplier AS (
    SELECT 
        tc.o_orderkey,
        tc.o_orderdate,
        tc.o_totalprice,
        tc.c_name,
        tc.c_acctbal,
        s.s_name AS supplier_name
    FROM 
        TopCustomers tc
    JOIN 
        lineitem l ON tc.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
SalesSummary AS (
    SELECT 
        c.c_name,
        COUNT(DISTINCT cs.o_orderkey) AS total_orders,
        SUM(cs.o_totalprice) AS total_spent,
        AVG(cs.o_totalprice) AS avg_order_value
    FROM 
        CustomerSupplier cs
    JOIN 
        customer c ON cs.c_name = c.c_name
    GROUP BY 
        c.c_name
)
SELECT 
    s.c_name,
    s.total_orders,
    s.total_spent,
    s.avg_order_value,
    r.r_name AS region_name
FROM 
    SalesSummary s
JOIN 
    nation n ON s.c_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.total_spent > (SELECT AVG(total_spent) FROM SalesSummary) 
ORDER BY 
    s.total_orders DESC;
