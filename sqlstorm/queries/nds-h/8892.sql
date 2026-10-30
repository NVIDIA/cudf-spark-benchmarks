WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
TopCustomers AS (
    SELECT 
        ro.c_name,
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate
    FROM 
        RankedOrders ro
    WHERE 
        ro.rnk <= 3
),
SupplyStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    tc.c_name,
    tc.o_orderkey,
    tc.o_totalprice,
    tc.o_orderdate,
    ss.total_available,
    ss.average_supply_cost
FROM 
    TopCustomers tc
JOIN 
    supplystats ss ON tc.o_orderkey = ss.ps_partkey
ORDER BY 
    tc.o_orderdate DESC, 
    tc.o_totalprice DESC
LIMIT 50;