
WITH  SupplierOrders AS (
    SELECT 
        s.s_name,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_filled,
        SUM(l.l_discount) AS total_discount,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CASE WHEN s.s_acctbal IS NULL THEN 'No Balance' ELSE 'Has Balance' END AS acct_status,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS bal_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        'No Balance' AS acct_status,
        ROW_NUMBER() OVER (ORDER BY s.s_suppkey) AS bal_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NULL
),
FinalResult AS (
    SELECT 
        so.s_name,
        so.total_filled,
        so.total_discount,
        fs.acct_status,
        fs.bal_rank,
        DENSE_RANK() OVER (ORDER BY so.total_filled DESC) AS filled_rank
    FROM 
        SupplierOrders so
    JOIN 
        FilteredSuppliers fs ON so.s_name = fs.s_name
    WHERE 
        so.order_count > 0
    ORDER BY 
        so.total_filled DESC, fs.bal_rank
)
SELECT 
    fr.s_name,
    fr.total_filled,
    fr.total_discount,
    fr.acct_status,
    CASE 
        WHEN fr.filled_rank IS NULL THEN 'Unranked'
        ELSE CAST(fr.filled_rank AS STRING)
    END AS filled_rank_status
FROM 
    FinalResult fr
WHERE 
    fr.total_filled > (SELECT AVG(total_filled) FROM SupplierOrders) 
    OR fr.acct_status = 'No Balance'
ORDER BY 
    fr.total_discount, fr.s_name
LIMIT 20;
