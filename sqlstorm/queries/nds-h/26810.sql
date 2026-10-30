WITH SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CONCAT(s.s_name, ' - ', p.p_name) AS SupplierPartName,
        LEFT(CONCAT(s.s_name, ' - ', p.p_name), 35) AS ShortSupplierPartName,
        CASE 
            WHEN p.p_retailprice > 100 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Cheap' 
        END AS PriceCategory
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNation AS (
    SELECT
        r.r_regionkey,
        r.r_name AS RegionName,
        n.n_name AS NationName,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_regionkey, r.r_name, n.n_name
),
FinalBenchmark AS (
    SELECT
        sp.SupplierPartName,
        COUNT(DISTINCT sp.s_suppkey) AS TotalSuppliers,
        SUM(sp.p_retailprice) AS TotalRetailPrice,
        AVG(sp.p_retailprice) AS AverageRetailPrice,
        rn.RegionName,
        rn.NationName,
        rn.SupplierCount
    FROM
        SupplierParts sp
    JOIN
        RegionNation rn ON sp.s_suppkey = rn.SupplierCount
    GROUP BY
        sp.SupplierPartName, rn.RegionName, rn.NationName, rn.SupplierCount
)
SELECT 
    *,
    LENGTH(SupplierPartName) AS NameLength,
    REPLACE(SupplierPartName, ' - ', ' ') AS CleanName,
    REPLACE(SupplierPartName, ' ', '_') AS UnderscoreName
FROM 
    FinalBenchmark
WHERE 
    TotalRetailPrice > 500

ORDER BY 
    AverageRetailPrice DESC, NameLength ASC;
