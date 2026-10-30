WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
), 
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        ps.ps_partkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SelectedOrders AS (
    SELECT 
        ro.*,
        CASE WHEN co.total_spent IS NULL THEN 'UNIQUE' ELSE 'REPEATED' END AS order_type
    FROM 
        RankedOrders ro
        LEFT JOIN CustomerOrders co ON ro.o_orderkey = co.c_custkey
    WHERE 
        ro.order_rank = 1 OR ro.o_totalprice > 1000
)
SELECT 
    so.o_orderkey, 
    so.o_orderdate,
    so.o_totalprice,
    si.s_name AS supplier_name,
    si.nation_name,
    ap.total_available,
    ap.avg_supply_cost,
    so.order_type
FROM 
    SelectedOrders so
LEFT JOIN 
    AvailableParts ap ON so.o_orderkey = ap.ps_partkey 
LEFT JOIN 
    SupplierInfo si ON ap.ps_partkey = si.part_count
WHERE 
    (so.o_totalprice IS NOT NULL AND so.o_totalprice <> 0) 
    OR 
    (so.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31')
ORDER BY 
    so.o_totalprice DESC,
    si.nation_name ASC;