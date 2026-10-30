WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        l.l_shipdate,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1998-01-01'
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) as total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
), OrdersWithHighLineItems AS (
    SELECT 
        o.o_orderkey,
        COUNT(*) AS lineitem_count
    FROM 
        orders o
    JOIN 
        RankedLineItems r ON o.o_orderkey = r.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(*) > 5
), CombinedData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COALESCE(f.total_supplycost, 0) AS supplier_cost,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        OrdersWithHighLineItems o
    JOIN 
        RankedLineItems l ON o.o_orderkey = l.l_orderkey
    LEFT OUTER JOIN 
        FilteredSuppliers f ON l.l_suppkey = f.s_suppkey
    GROUP BY 
        o.o_orderkey, f.total_supplycost
), FinalReport AS (
    SELECT 
        *,
        CASE 
            WHEN total_revenue > supplier_cost THEN 'Profitable'
            WHEN total_revenue < supplier_cost THEN 'Unprofitable'
            ELSE 'Break-even'
        END AS profitability_status
    FROM 
        CombinedData
)
SELECT 
    fr.o_orderkey,
    fr.total_revenue,
    fr.supplier_cost,
    fr.profitability_status
FROM 
    FinalReport fr
WHERE 
    fr.revenue_rank <= 10
ORDER BY 
    fr.total_revenue DESC;

