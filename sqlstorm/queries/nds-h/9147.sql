WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
TopCustomers AS (
    SELECT 
        rank, 
        nation_name,
        o_orderkey,
        o_orderdate,
        o_totalprice,
        c_name
    FROM 
        RankedOrders
    WHERE 
        rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    tc.nation_name,
    tc.c_name,
    tc.o_orderkey,
    tc.o_orderdate,
    tc.o_totalprice,
    SUM(sd.ps_supplycost) AS total_supply_cost
FROM 
    TopCustomers tc
JOIN 
    lineitem l ON tc.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails sd ON l.l_partkey = sd.ps_partkey
GROUP BY 
    tc.nation_name, tc.c_name, tc.o_orderkey, tc.o_orderdate, tc.o_totalprice
ORDER BY 
    tc.nation_name, total_supply_cost DESC;
