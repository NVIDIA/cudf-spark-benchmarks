WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), SupplierCustomer AS (
    SELECT sd.s_suppkey, cd.c_custkey, cd.TotalSpent, sd.TotalCost, nd.n_name AS NationName
    FROM SupplierDetails sd
    JOIN CustomerDetails cd ON sd.TotalCost > cd.TotalSpent
    JOIN nation na ON sd.s_nationkey = na.n_nationkey
    JOIN NationDetails nd ON na.n_nationkey = nd.n_nationkey
)
SELECT sc.NationName, COUNT(DISTINCT sc.c_custkey) AS CustomerCount, 
       SUM(sc.TotalSpent) AS TotalCustomerSpent, 
       SUM(sc.TotalCost) AS TotalSupplierCost
FROM SupplierCustomer sc
GROUP BY sc.NationName
ORDER BY CustomerCount DESC, TotalCustomerSpent DESC;
