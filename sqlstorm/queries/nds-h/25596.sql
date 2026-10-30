
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        ns.n_name AS nation_name, 
        rs.s_name AS supplier_name, 
        rs.s_acctbal AS account_balance
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    ts.supplier_name, 
    COUNT(pd.p_partkey) AS parts_count, 
    SUM(pd.profit_margin) AS total_profit_margin,
    AVG(pd.p_retailprice) AS avg_retail_price
FROM 
    TopSuppliers ts
LEFT JOIN 
    PartDetails pd ON ts.supplier_name = pd.p_name
GROUP BY 
    ts.region_name, 
    ts.nation_name, 
    ts.supplier_name
ORDER BY 
    ts.region_name, 
    ts.nation_name, 
    total_profit_margin DESC;
