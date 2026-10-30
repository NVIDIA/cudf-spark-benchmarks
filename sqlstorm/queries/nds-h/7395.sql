WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 10
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        ps.ps_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        t.o_orderkey,
        t.o_orderdate,
        t.o_totalprice,
        t.c_name,
        t.nation_name,
        p.p_name,
        p.total_supply_cost
    FROM 
        TopOrders t
    JOIN 
        PartSuppliers p ON t.o_orderkey = p.ps_partkey
    ORDER BY 
        t.o_orderdate DESC, t.o_totalprice DESC
)
SELECT 
    o_orderkey,
    o_orderdate,
    o_totalprice,
    c_name,
    nation_name,
    p_name,
    total_supply_cost
FROM 
    FinalReport
WHERE 
    total_supply_cost > 1000
LIMIT 100;