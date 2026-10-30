WITH TotalSales AS (
    SELECT 
        l_partkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS total_price,
        COUNT(l_orderkey) AS order_count
    FROM 
        lineitem
    WHERE 
        l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
    GROUP BY 
        l_partkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSales AS (
    SELECT 
        ts.l_partkey,
        ts.total_price,
        RANK() OVER (ORDER BY ts.total_price DESC) AS price_rank
    FROM 
        TotalSales ts
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(rs.total_price, 0) AS total_price,
        COALESCE(si.total_supply_cost, 0) AS total_supply_cost,
        rs.price_rank
    FROM 
        part p
    LEFT JOIN 
        RankedSales rs ON p.p_partkey = rs.l_partkey
    LEFT JOIN 
        SupplierInfo si ON p.p_partkey = si.s_suppkey
    WHERE 
        (p.p_size > 20 OR p.p_retailprice < 100)
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.total_price,
    fr.total_supply_cost,
    fr.price_rank,
    CASE 
        WHEN fr.total_price IS NULL THEN 'No sales'
        ELSE 'Sales recorded'
    END AS sales_status
FROM 
    FinalResults fr
WHERE 
    fr.price_rank IS NOT NULL
ORDER BY 
    fr.total_price DESC, fr.p_partkey
LIMIT 100;