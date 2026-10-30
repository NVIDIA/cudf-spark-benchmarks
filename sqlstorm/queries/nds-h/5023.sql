WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.rank <= 10
),
AggregateSupplier AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
SupplierDetails AS (
    SELECT 
        n.n_name,
        a.total_supply_cost
    FROM 
        nation n
    JOIN 
        AggregateSupplier a ON n.n_nationkey = a.s_nationkey
)
SELECT 
    T.o_orderkey,
    T.o_orderdate,
    T.o_totalprice,
    T.c_mktsegment,
    S.n_name,
    S.total_supply_cost
FROM 
    TopOrders T
JOIN 
    SupplierDetails S ON T.o_orderkey % 5 = S.total_supply_cost % 5
ORDER BY 
    T.o_totalprice DESC, S.total_supply_cost ASC
LIMIT 50;