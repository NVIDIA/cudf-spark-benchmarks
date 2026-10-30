WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        c.c_nationkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.c_name,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pp.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY pp.total_supply_cost DESC) AS part_rank
    FROM 
        part p
    LEFT JOIN 
        SupplierSummary pp ON p.p_partkey = pp.ps_partkey
)
SELECT 
    t.o_orderkey,
    t.c_name,
    t.o_orderdate,
    t.o_totalprice,
    pd.p_name,
    pd.total_supply_cost
FROM 
    TopOrders t
LEFT JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    pd.part_rank IS NOT NULL OR pd.total_supply_cost IS NULL
ORDER BY 
    t.o_totalprice DESC, t.o_orderdate ASC;