
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        r.r_name AS region_name,
        c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
SupplierInfo AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_value,
        fc.c_name AS customer_name,
        fc.region_name
    FROM RankedSuppliers rs
    JOIN FilteredCustomers fc ON rs.s_suppkey = fc.c_custkey
    WHERE rs.rank <= 5
)
SELECT 
    si.s_name AS Supplier_Name,
    si.customer_name AS Customer_Name,
    si.total_supply_value AS Total_Supply_Value,
    si.region_name AS Region
FROM SupplierInfo si
ORDER BY si.region_name, si.total_supply_value DESC;
