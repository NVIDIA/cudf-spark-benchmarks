WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
AggregatedSupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM 
        partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        (CASE 
            WHEN s.s_acctbal IS NULL THEN 'N/A'
            WHEN s.s_acctbal > (
                SELECT AVG(s2.s_acctbal) FROM supplier s2
            ) THEN 'Above Average'
            ELSE 'Below Average'
        END) AS acctbal_comparison
    FROM 
        supplier s
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(s.s_suppkey) > 0
)
SELECT 
    r.r_name,
    fn.n_name,
    sd.s_name,
    sd.acctbal_comparison,
    a.unique_parts,
    a.total_supply_cost,
    o.o_orderkey,
    o.o_orderdate
FROM 
    region r
JOIN 
    filteredNations fn ON r.r_regionkey = fn.n_nationkey
JOIN 
    supplierDetails sd ON sd.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_size BETWEEN 1 AND 10
        )
    )
LEFT JOIN 
    AggregatedSupplierCosts a ON sd.s_suppkey = a.ps_suppkey
JOIN 
    RankedOrders o ON o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_quantity > (
            SELECT AVG(l2.l_quantity) FROM lineitem l2
        ) AND l.l_shipdate IS NOT NULL
    )
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    r.r_name, fn.n_name, sd.s_name;