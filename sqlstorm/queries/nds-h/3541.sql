
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank,
        p.p_partkey,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, s.s_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierSummary AS (
    SELECT 
        ns.n_name, 
        COUNT(DISTINCT fs.s_suppkey) AS num_suppliers,
        AVG(fs.total_supply_cost) AS avg_supply_cost
    FROM 
        RankedSuppliers fs
    JOIN 
        nation ns ON fs.s_nationkey = ns.n_nationkey
    WHERE 
        fs.supply_rank = 1
    GROUP BY 
        ns.n_name
),
FinalResults AS (
    SELECT 
        fo.o_orderkey, 
        fs.n_name AS supplier_nation, 
        fo.total_revenue,
        COALESCE(fs.avg_supply_cost, 0) AS avg_supply_cost
    FROM 
        FilteredOrders fo
    LEFT JOIN 
        SupplierSummary fs ON fs.num_suppliers > 0
)

SELECT 
    fr.o_orderkey,
    fr.supplier_nation,
    fr.total_revenue,
    fr.avg_supply_cost
FROM 
    FinalResults fr
ORDER BY 
    fr.total_revenue DESC
LIMIT 10;
