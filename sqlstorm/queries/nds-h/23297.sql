
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'P')
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= (SELECT MAX(o.o_orderdate) FROM orders o WHERE o.o_orderstatus = 'O')
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FinalResults AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        COALESCE(fli.total_price, 0) AS calculated_price,
        COALESCE(ss.part_count, 0) AS supplier_count,
        CASE 
            WHEN ro.o_orderstatus = 'O' THEN 'Processed'
            ELSE 'Pending'
        END AS order_status,
        r.region_comment AS region_detail
    FROM 
        RankedOrders ro
    LEFT JOIN 
        FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
    LEFT JOIN 
        (
            SELECT r.r_regionkey, r.r_comment AS region_comment
            FROM region r
            WHERE r.r_name LIKE 'A%'
        ) r ON ro.o_orderkey % 5 = r.r_regionkey
    LEFT JOIN 
        SupplierStats ss ON ss.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            GROUP BY ps.ps_suppkey
            HAVING SUM(ps.ps_supplycost) < (SELECT AVG(s.s_acctbal) FROM supplier s) 
            LIMIT 1
        )
    WHERE 
        ro.rank <= 10
)
SELECT 
    fr.o_orderkey,
    fr.o_totalprice,
    fr.calculated_price,
    fr.supplier_count,
    fr.order_status,
    LENGTH(fr.region_detail) AS region_length
FROM 
    FinalResults fr
ORDER BY 
    fr.o_totalprice DESC, fr.o_orderkey ASC
LIMIT 50;
