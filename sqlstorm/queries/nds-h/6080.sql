
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(c.c_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(ro.total_revenue) AS avg_order_revenue,
    MAX(ts.total_supply_cost) AS max_supplier_cost,
    SUM(hv.total_account_balance) AS national_account_balance
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
JOIN 
    TopSuppliers ts ON ts.total_supply_cost = (SELECT MAX(ts2.total_supply_cost) FROM TopSuppliers ts2)
JOIN 
    HighValueNations hv ON n.n_nationkey = hv.n_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
