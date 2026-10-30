
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
RegionSales AS (
    SELECT 
        n.n_nationkey,
        SUM(CASE 
            WHEN o.o_orderstatus = 'O' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS total_revenue
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
), 
SupplierPartAvailable AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rank <= 5
), 
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE((SELECT SUM(spa.ps_availqty) FROM SupplierPartAvailable spa WHERE spa.ps_partkey = p.p_partkey), 0) AS total_available
    FROM 
        part p
    WHERE 
        (p.p_size > 10 AND p.p_type NOT LIKE '%a%')
        OR (p.p_type LIKE '%b%' AND p.p_retailprice < 50.00)
), 
TopRegions AS (
    SELECT 
        rs.n_nationkey,
        SUM(rs.total_revenue) AS regional_revenue
    FROM 
        RegionSales rs
    WHERE 
        rs.total_revenue IS NOT NULL 
    GROUP BY 
        rs.n_nationkey
    HAVING 
        SUM(rs.total_revenue) > (SELECT AVG(total_revenue) FROM RegionSales)
)

SELECT 
    p.p_name,
    p.p_retailprice,
    p.total_available,
    CASE 
        WHEN tr.regional_revenue IS NOT NULL THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_status
FROM 
    FilteredParts p
LEFT JOIN 
    TopRegions tr ON p.p_partkey IN (SELECT spa.ps_partkey FROM SupplierPartAvailable spa WHERE spa.ps_availqty > 100)
WHERE 
    p.total_available > 0
ORDER BY 
    p.p_retailprice DESC, 
    p.p_name ASC;
