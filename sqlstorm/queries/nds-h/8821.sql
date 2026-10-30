WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate
    FROM 
        RankedOrders ro
    WHERE 
        ro.total_price_rank <= 10
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name as supplier_name,
        ps.ps_supplycost,
        p.p_name as part_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
Summary AS (
    SELECT 
        t.o_orderkey,
        COUNT(DISTINCT spd.supplier_name) AS supplier_count,
        SUM(spd.ps_supplycost) AS total_supply_cost
    FROM 
        TopOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    JOIN 
        SupplierPartDetails spd ON l.l_partkey = spd.ps_partkey
    GROUP BY 
        t.o_orderkey
)
SELECT 
    s.o_orderkey,
    s.supplier_count,
    s.total_supply_cost,
    t.o_totalprice,
    t.o_orderdate
FROM 
    Summary s
JOIN 
    TopOrders t ON s.o_orderkey = t.o_orderkey
ORDER BY 
    t.o_totalprice DESC;