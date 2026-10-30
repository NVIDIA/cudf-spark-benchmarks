WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartAvailability AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) as line_item_count,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            ELSE 'Pending'
        END AS order_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_price,
        od.line_item_count,
        od.order_status,
        COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_linenumber END) AS return_count
    FROM 
        OrderDetails od
    LEFT JOIN 
        lineitem l ON od.o_orderkey = l.l_orderkey
    GROUP BY 
        od.o_orderkey, od.total_price, od.line_item_count, od.order_status
)
SELECT 
    pa.p_partkey,
    pa.total_available,
    o.o_orderkey,
    o.total_price,
    o.line_item_count,
    o.order_status,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name
FROM 
    PartAvailability pa
LEFT JOIN 
    lineitem l ON pa.p_partkey = l.l_partkey
LEFT JOIN 
    FilteredOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey AND rs.rn = 1
WHERE 
    (pa.total_available IS NULL OR pa.total_available > 0)
    AND (o.total_price IS NOT NULL OR o.total_price < 10000)
ORDER BY 
    pa.total_available DESC, 
    o.order_status ASC, 
    o.total_price DESC NULLS LAST;
