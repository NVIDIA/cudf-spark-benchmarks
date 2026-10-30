
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_nationkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_orderkey = c.c_custkey
    WHERE 
        o.order_rank <= 10
    GROUP BY 
        c.c_nationkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_nationkey
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    td.c_name AS customer_name,
    SUM(td.total_spent) AS total_spending,
    AVG(sd.ps_supplycost) AS avg_supply_cost,
    MAX(sd.ps_availqty) AS max_avail_qty
FROM 
    TopCustomers td
JOIN 
    SupplierDetails sd ON td.c_nationkey = sd.s_nationkey
GROUP BY 
    td.c_name
ORDER BY 
    total_spending DESC, avg_supply_cost ASC
LIMIT 20;
