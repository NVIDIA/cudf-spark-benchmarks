
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_regionkey
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            WHEN o.o_orderstatus = 'O' THEN 'Pending'
            ELSE 'Unknown' 
        END AS order_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
        AND o.o_totalprice IS NOT NULL
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity * (1 - l.l_discount)) AS total_quantity,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    f.o_orderkey,
    f.o_totalprice,
    l.total_quantity,
    ss.s_name,
    ss.total_supplycost
FROM 
    FilteredOrders f
LEFT JOIN 
    LineItemSummary l ON f.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers ss ON ss.supplier_rank <= 3
WHERE 
    f.o_totalprice IS NOT NULL
    AND (ss.total_supplycost IS NOT NULL OR l.total_quantity IS NULL)
ORDER BY 
    f.o_orderkey DESC, ss.total_supplycost DESC;
