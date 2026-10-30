WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
DistinctNations AS (
    SELECT DISTINCT 
        n.n_nationkey, n.n_name
    FROM 
        nation n
    WHERE 
        n.n_comment LIKE '%lead%'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(sp.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(sp.avg_supply_cost, 0.00) AS avg_supply_cost,
    ns.n_name,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Open'
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown'
    END AS order_status,
    DENSE_RANK() OVER (PARTITION BY ns.n_nationkey ORDER BY r.o_totalprice DESC) AS price_rank
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts sp ON r.o_orderkey = sp.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    DistinctNations ns ON ts.s_suppkey = ns.n_nationkey
WHERE 
    r.rn <= 10
ORDER BY 
    r.o_orderdate DESC, price_rank;
