WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT 
        sd.*,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierDetails sd
)
SELECT 
    rs.s_name,
    rs.nation_name,
    COALESCE(od.total_value, 0) AS order_value,
    rs.part_count,
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
LEFT JOIN 
    OrderDetails od ON rs.s_suppkey = od.o_orderkey  
WHERE 
    rs.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    AND rs.supplier_rank <= 10
UNION ALL
SELECT 
    'Total' AS s_name,
    NULL AS nation_name,
    SUM(COALESCE(od.total_value, 0)) AS order_value,
    NULL AS part_count,
    SUM(rs.total_supply_cost) AS total_supply_cost
FROM 
    RankedSuppliers rs
LEFT JOIN 
    OrderDetails od ON rs.s_suppkey = od.o_orderkey
WHERE 
    rs.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier);