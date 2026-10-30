WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
TopParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(ss.total_account_balance, 0)) AS total_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierStats ss ON s.s_nationkey = ss.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name, n.n_name
)
SELECT 
    r.r_name,
    r.nation_name,
    COALESCE(ts.total_supplycost, 0) AS total_part_supplycost,
    r.total_balance,
    os.order_revenue,
    os.item_count
FROM 
    RegionSummary r
LEFT JOIN 
    TopParts ts ON ts.ps_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 day'
    )
LEFT JOIN 
    OrderDetails os ON os.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o 
        WHERE o.o_orderstatus = 'F'
        AND o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '90 day'
    )
WHERE 
    r.total_balance IS NOT NULL 
ORDER BY 
    r.supplier_count DESC, 
    os.order_revenue DESC
LIMIT 100;