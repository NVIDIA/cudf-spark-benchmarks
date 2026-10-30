WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.s_acctbal
    FROM 
        SupplierInfo si
    WHERE 
        si.rank_acctbal = 1
),
PartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    p.p_partkey,
    p.p_name,
    pa.total_availqty,
    hv.s_name AS supplier_name,
    hv.s_acctbal AS supplier_acctbal,
    od.net_revenue,
    CASE 
        WHEN od.o_orderstatus = 'O' THEN 'Pending'
        WHEN od.o_orderstatus = 'F' THEN 'Filled'
        ELSE 'Other'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY pa.ps_partkey ORDER BY od.net_revenue DESC) AS order_rank
FROM 
    part p
LEFT JOIN 
    PartAvailability pa ON p.p_partkey = pa.ps_partkey
FULL OUTER JOIN 
    HighValueSuppliers hv ON hv.s_suppkey = pa.unique_suppliers
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = pa.ps_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND (hv.s_acctbal > 1000 OR hv.s_acctbal IS NULL)
    AND (od.net_revenue IS NOT NULL AND od.line_item_count > 0)
ORDER BY 
    p.p_partkey, order_rank DESC
LIMIT 100;
